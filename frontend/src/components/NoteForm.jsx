import { useState } from "react";

function NoteForm({ onClose, onAdd }) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();

    if (!title.trim() || !body.trim()) {
      return;
    }

    const noteData = {
      title: title.trim(),
      body: body.trim(),
    };

    try {
      setIsSubmitting(true);

      await onAdd(noteData);

      setTitle("");
      setBody("");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4">
      <form
        onSubmit={handleSubmit}
        className="
          w-full
          max-w-lg
          rounded-2xl
          border
          border-[#252A33]
          bg-[#181B21]
          p-6
          shadow-[0_20px_60px_rgba(0,0,0,0.4)]
        "
      >
        {/* Header */}
        <div className="mb-6 flex items-center justify-between">
          <h2 className="text-2xl font-semibold text-[#F1F5F9]">
            Новая заметка
          </h2>

          <button
            type="button"
            onClick={onClose}
            disabled={isSubmitting}
            className="
              cursor-pointer
              text-2xl
              text-[#64748B]
              transition
              hover:text-[#F1F5F9]
              disabled:cursor-not-allowed
              disabled:opacity-50
            "
          >
            ×
          </button>
        </div>

        {/* Title */}
        <input
          type="text"
          placeholder="Название заметки"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          disabled={isSubmitting}
          className="
            mb-4
            w-full
            rounded-xl
            border
            border-[#252A33]
            bg-[#0F1115]
            px-4
            py-3
            text-[#F1F5F9]
            outline-none
            placeholder:text-[#64748B]
            focus:border-[#60A5FA]
            disabled:opacity-50
          "
        />

        {/* Body */}
        <textarea
          placeholder="Текст заметки"
          value={body}
          onChange={(event) => setBody(event.target.value)}
          disabled={isSubmitting}
          className="
            mb-6
            min-h-40
            w-full
            resize-y
            rounded-xl
            border
            border-[#252A33]
            bg-[#0F1115]
            px-4
            py-3
            text-[#F1F5F9]
            outline-none
            placeholder:text-[#64748B]
            focus:border-[#60A5FA]
            disabled:opacity-50
          "
        />

        {/* Buttons */}
        <div className="flex justify-end gap-3">
          <button
            type="button"
            onClick={onClose}
            disabled={isSubmitting}
            className="
              cursor-pointer
              rounded-xl
              px-5
              py-3
              text-[#94A3B8]
              transition
              hover:bg-[#252A33]
              hover:text-[#F1F5F9]
              disabled:cursor-not-allowed
              disabled:opacity-50
            "
          >
            Отмена
          </button>

          <button
            type="submit"
            disabled={isSubmitting}
            className="
              cursor-pointer
              rounded-xl
              bg-[#60A5FA]
              px-5
              py-3
              font-medium
              text-[#0F1115]
              transition
              hover:bg-[#93C5FD]
              disabled:cursor-not-allowed
              disabled:opacity-50
            "
          >
            {isSubmitting ? "Создание..." : "Создать"}
          </button>
        </div>
      </form>
    </div>
  );
}

export default NoteForm;